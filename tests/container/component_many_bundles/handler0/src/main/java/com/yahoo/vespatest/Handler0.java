// Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
package com.yahoo.vespatest;

import com.yahoo.jdisc.Request;
import com.yahoo.jdisc.Response;
import com.yahoo.jdisc.handler.*;

public class Handler0 extends AbstractRequestHandler {

    @Override
    public ContentChannel handleRequest(Request request, ResponseHandler handler) {
        FastContentWriter writer = ResponseDispatch.newInstance(Response.Status.OK).connectFastWriter(handler);
        writer.write("Handler0");
        writer.close();
        return null;
    }
}
