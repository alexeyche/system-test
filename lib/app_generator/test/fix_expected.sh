#!/bin/sh
# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.

for file in *.actual; do
    cp $file ${file%.actual}
done
