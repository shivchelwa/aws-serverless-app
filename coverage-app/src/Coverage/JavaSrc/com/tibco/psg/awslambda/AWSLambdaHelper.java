package com.tibco.psg.awslambda;

import com.tibco.be.model.functions.BEPackage;
import static com.tibco.be.model.functions.FunctionDomain.ACTION;

import com.amazonaws.regions.Regions;
import com.amazonaws.services.lambda.AWSLambda;
import com.amazonaws.services.lambda.AWSLambdaClientBuilder;
import com.amazonaws.services.lambda.model.InvokeRequest;
import com.amazonaws.services.lambda.model.InvokeResult;

@BEPackage(catalog = "AWS", category = "Lambda")
public class AWSLambdaHelper {

	@com.tibco.be.model.functions.BEFunction(
		name = "client", 
		description = "Creates a client for AWS Lambda.", 
		signature = "Object client(String region)", 
		params = { 
			@com.tibco.be.model.functions.FunctionParamDescriptor(name = "region", type = "String", desc = "AWS region, e.g., us-west-2") 
		}, 
		freturn = @com.tibco.be.model.functions.FunctionParamDescriptor(name = "", type = "AWSLambda", desc = "Client object used to invoke AWS functions."), 
		version = "1.0", see = "", mapper = @com.tibco.be.model.functions.BEMapper(), 
		cautions = "none", fndomain = { ACTION }, example = "Object c = Lambda.client(&quot;us-west-2&quot;);")
	public static Object client(String region) {
		AWSLambdaClientBuilder builder = AWSLambdaClientBuilder.standard()
                .withRegion(Regions.fromName(region));
		return builder.build();
	}

	@com.tibco.be.model.functions.BEFunction(
		name = "invoke", 
		description = "Invoke a specified AWS Lambda function.", 
		signature = "String invoke(AWSLambda client, String function, String payload)", 
		params = { 
			@com.tibco.be.model.functions.FunctionParamDescriptor(name = "client", type = "AWSLambda", desc = "AWS Lambda client returned by Lambda.client()"),
			@com.tibco.be.model.functions.FunctionParamDescriptor(name = "function", type = "String", desc = "Name of the lambda function"),
			@com.tibco.be.model.functions.FunctionParamDescriptor(name = "payload", type = "String", desc = "Payload of the request for the lambda function")
		}, 
		freturn = @com.tibco.be.model.functions.FunctionParamDescriptor(name = "", type = "String", desc = "Payload of the response."), 
		version = "1.0", see = "", mapper = @com.tibco.be.model.functions.BEMapper(), 
		cautions = "none", fndomain = { ACTION }, example = "String result = Lambda.invoke(client, &quot;arn:coverage-ref&quot;, &quot;{...}&quot;);")
	public static String invoke(Object client, String function, String payload) {
		InvokeRequest req = new InvokeRequest()
                .withFunctionName(function)
                .withPayload(payload);
		InvokeResult result = ((AWSLambda) client).invoke(req);
		return new String(result.getPayload().array());
	}
}
