package org.apache.tomee.website;

import com.orientechnologies.orient.core.Orient;
import lombok.RequiredArgsConstructor;
import org.apache.commons.configuration.CompositeConfiguration;
import org.apache.tomee.embedded.Configuration;
import org.apache.tomee.embedded.Container;
import org.jbake.app.ConfigUtil;
import org.jbake.app.Oven;

import java.io.File;
import java.io.IOException;
import java.nio.file.ClosedWatchServiceException;
import java.nio.file.Path;
import java.nio.file.WatchEvent;
import java.nio.file.WatchKey;
import java.nio.file.WatchService;
import java.util.Scanner;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Stream;

import static java.nio.file.StandardWatchEventKinds.ENTRY_CREATE;
import static java.nio.file.StandardWatchEventKinds.ENTRY_DELETE;
import static java.nio.file.StandardWatchEventKinds.ENTRY_MODIFY;
import static lombok.AccessLevel.PRIVATE;

@RequiredArgsConstructor(access = PRIVATE)
public class JBake {
    public static void main(final String[] args) throws Exception {
        System.setProperty("java.util.concurrent.ForkJoinPool.common.parallelism", "64"); // try to have parallelStream better than default

        final File source = args == null || args.length < 1 ? new File("src/main/jbake") : new File(args[0]);
        final File pdfSource = new File(source, "content");
        final File destination = args == null || args.length < 2 ? new File("target/site-tmp") : new File(args[1]);
        final boolean startHttp = args == null || args.length < 2 || Boolean.parseBoolean(args[2]); // by default we dev
        final boolean skipPdf = args == null || args.length < 3 || Boolean.parseBoolean(args[3]); // by default...too slow sorry

        final Runnable build = () -> {
            System.out.println("Building TomEE website in " + destination);
            final Orient orient = Orient.instance();
            try {
                orient.startup();

                final Oven oven = new Oven(source, destination, new CompositeConfiguration() {{
                    addConfiguration(ConfigUtil.load(source));
                }}, true);
                oven.setupPaths();

                System.out.println("  > baking");
                oven.bake();

                if (!skipPdf) {
                    System.out.println("  > pdfifying");
                    PDFify.generatePdf(pdfSource, destination);
                }

                System.out.println("  > done :)");
            } catch (final Exception e) {
                e.printStackTrace();
            } finally {
                orient.shutdown();
            }
        };

        build.run();
        if (startHttp) {
            final Path watched = source.toPath();
            final WatchService watchService = watched.getFileSystem().newWatchService();
            watched.register(watchService, ENTRY_CREATE, ENTRY_DELETE, ENTRY_MODIFY);
            final AtomicBoolean run = new AtomicBoolean(true);
            final AtomicLong render = new AtomicLong(-1);
            final Thread renderingThread = new Thread() {
                {
                    setName("jbake-renderer");
                }

                @Override
                public void run() {
                    long last = System.currentTimeMillis();
                    while (run.get()) {
                        if (render.get() > last) {
                            last = System.currentTimeMillis();
                            try {
                                build.run();
                            } catch (final Throwable oops) {
                                oops.printStackTrace();
                            }
                        }
                        try {
                            sleep(TimeUnit.SECONDS.toMillis(1));
                        } catch (final InterruptedException e) {
                            Thread.interrupted();
                            break;
                        }
                    }
                }
            };
            final Thread watcherThread = new Thread() {
                {
                    setName("jbake-file-watcher");
                }

                @Override
                public void run() {
                    while (run.get()) {
                        try {
                            final WatchKey key = watchService.poll(1, TimeUnit.SECONDS);
                            if (key == null) {
                                continue;
                            }

                            for (final WatchEvent<?> event : key.pollEvents()) {
                                final WatchEvent.Kind<?> kind = event.kind();
                                if (kind != ENTRY_CREATE && kind != ENTRY_DELETE && kind != ENTRY_MODIFY) {
                                    continue; // unlikely but better to protect ourself
                                }

                                final Path updatedPath = Path.class.cast(event.context());
                                if (kind == ENTRY_DELETE || updatedPath.toFile().isFile()) {
                                    final String path = updatedPath.toString();
                                    if (!path.contains("___jb") && !path.endsWith("~")) {
                                        render.set(System.currentTimeMillis());
                                    }
                                }
                            }
                            key.reset();
                        } catch (final InterruptedException e) {
                            Thread.interrupted();
                            run.compareAndSet(true, false);
                        } catch (final ClosedWatchServiceException cwse) {
                            if (!run.get()) {
                                throw new IllegalStateException(cwse);
                            }
                        }
                    }
                }
            };

            renderingThread.start();
            watcherThread.start();

            final Runnable onQuit = () -> {
                run.compareAndSet(true, false);
                Stream.of(watcherThread, renderingThread).forEach(thread -> {
                    try {
                        thread.join();
                    } catch (final InterruptedException e) {
                        Thread.interrupted();
                    }
                });
                try {
                    watchService.close();
                } catch (final IOException ioe) {
                    // not important
                }
            };

            try (final Container container = new Container(new Configuration() {{
                setWebResourceCached(false);
                property("openejb.additional.exclude", "logback,jbake");
            }}).deployClasspathAsWebApp(null, destination)) {
                System.out.println("Started on http://localhost:" + container.getConfiguration().getHttpPort());

                final Scanner console = new Scanner(System.in);
                String cmd;
                while (((cmd = console.nextLine())) != null) {
                    if ("quit".equals(cmd)) {
                        return;
                    } else if ("r".equals(cmd) || "rebuild".equals(cmd) || "build".equals(cmd) || "b".equals(cmd)) {
                        render.set(System.currentTimeMillis());
                    } else {
                        System.err.println("Ignoring " + cmd + ", please use 'build' or 'quit'");
                    }
                }
            }
            onQuit.run();
        }
    }
}
