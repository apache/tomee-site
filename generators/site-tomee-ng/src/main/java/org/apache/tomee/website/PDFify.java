/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.tomee.website;

import lombok.RequiredArgsConstructor;
import org.asciidoctor.Asciidoctor;
import org.asciidoctor.AttributesBuilder;

import java.io.File;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static lombok.AccessLevel.PRIVATE;
import static org.asciidoctor.OptionsBuilder.options;

@RequiredArgsConstructor(access = PRIVATE)
public class PDFify {
    public static void generatePdf(final File from, final File targetBase) throws IOException {
        final Path sourceBase = from.toPath();
        final Asciidoctor asciidoctor = Asciidoctor.Factory.create();
        final ExecutorService pool = Executors.newFixedThreadPool(16);
        Files.walkFileTree(sourceBase, new SimpleFileVisitor<Path>() {
            @Override
            public FileVisitResult visitFile(final Path file, final BasicFileAttributes attrs) throws IOException {
                final String fileName = file.getFileName().toString();
                if (fileName.endsWith(".adoc")) {
                    pool.submit(() -> {
                        final String path = sourceBase.relativize(file).toString();
                        final File target = new File(targetBase, path.substring(0, path.length() - "adoc".length()) + "pdf");
                        final File asFile = file.toFile();
                        final Map<String, Object> attributes = asciidoctor.readDocumentHeader(asFile).getAttributes();
                        // if we generate the PDF link we need to create the PDF excepted if it is expected to be manual
                        if (attributes.containsKey("jbake-tomeepdf") && !attributes.containsKey("jbake-tomeepdf-manual")) {
                            asciidoctor.convertFile(
                                    asFile,
                                    options().docType("article")
                                            .backend
                                            ("pdf")
                                    .attributes(AttributesBuilder.attributes().attribute("source-highlighter", "coderay")).toFile(target).get());
                            System.out.println("Generated " + target);
                        }
                    });
                }
                return super.visitFile(file, attrs);
            }
        });
        pool.shutdown();
        try {
            pool.awaitTermination(1, TimeUnit.HOURS);
        } catch (final InterruptedException e) {
            Thread.interrupted();
        }
    }
}
