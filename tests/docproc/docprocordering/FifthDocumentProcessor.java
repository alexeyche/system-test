// Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
package com.yahoo.vespatest;

import com.yahoo.docproc.Processing;
import com.yahoo.document.Document;
import com.yahoo.document.DocumentOperation;
import com.yahoo.document.DocumentPut;
import com.yahoo.document.datatypes.Array;
import com.yahoo.document.datatypes.StringFieldValue;

import com.yahoo.vespatest.order.OrderDocumentProcessor;

/**
 * @author Einar M R Rosenvinge
 */
public class FifthDocumentProcessor extends OrderDocumentProcessor {

    @Override
    public Progress process(Processing processing) {
        for (DocumentOperation op : processing.getDocumentOperations()) {
            if (op instanceof DocumentPut) {
                Document document = ((DocumentPut)op).getDocument();
                Array<StringFieldValue> stringArray = (Array<StringFieldValue>) document.getFieldValue("stringarray");

                assertArraySize(stringArray, 4);
                assertArray(stringArray, 0, new StringFieldValue("first"));
                assertArray(stringArray, 1, new StringFieldValue("second"));
                assertArray(stringArray, 2, new StringFieldValue("third"));
                assertArray(stringArray, 3, new StringFieldValue("fourth"));

                stringArray.add(new StringFieldValue("fifth"));
            }
        }
        return Progress.DONE;
    }
}
