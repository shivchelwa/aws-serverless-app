# coverage-app

This is a TIBCO BusinessEvents project to demostrate the deployment on Kubernetes. It implements coverage rules in either BE rules, or BE decision tables.  Decision table contains easy-to-edit rules in tabular format, and they can be hot-deployed at runtime.  

It also demonstrates the integration with Redis cache via either direct invocation of AWS lambda functions, or via REST API through the AWS API gateway. The direct lambda call is faster because it avoids the round-trip delay to the API gateway, which could save 100 ms or more.  To enable the direct lambda invocation, we have to configure the service role of the EKS cluster, which has been done in the script `eks/aws/efs-sg-rule.sh`.

The coverage service instances are deployed in muliple PODs, and the service is exposed by a LoadBalancer service.  Thus, the coverage service can be auto scaled as described in [kuberneties.io](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/).

## Develop BE applications

After you install the TIBCO BusinessEvents 5.5.0 or above, you can launch the BE studio, and import the project source code from `./src/Coverage`.  Then, right click the project root in the "Studio Explorer", and select "Properties". Select "Java Build Path", then edit the jars under the "Libraries" tab.  Notice that this project has compile-time dependency to 2 aws-java-sdk jars for direct invocation of AWS lambda functions.  You need to fix the path of these 2 jars to match your project location. One way to fix the path is to remove and then add them back with correct path.  This step can be automated if you use Maven.

## Test BE application locally

This project uses a few third-party jars, which are under the `./build` folder.  You can build the project from the BE studio, or by using the script `${BE_HOME}/studio/bin/studio-tools`. An example for the use of the script is shown in `./build_image.sh`.  Put the result of the build, `Coverage.ear`, in the folder `./build`.

Set env `$BE_HOME` to your TIBCO installation folder, e.g., `/opt/tibco/be/5.5`. Edit the file `${BE_HOME}/bin/be-engine.tra` to add `./build` to the Java classpath, e.g.,
```bash
tibco.env.CUSTOM_EXT_PREPEND_CP=/path/to/poc/coverage-app/build
```
You can then start the BE engine locally by calling the script `./start-engine.sh`.

## Build and upload docker images
You can build the docker image for this BE application, and push it to AWS ECR using the following scripts, so the application can be deployed and started on EC2.
```bash
./build_image.sh
./push_images.sh
```

## Deploy and start coverage service
After the docker image is pushed to ECR, you can use the following script deploy and start the coverage service on the EKS cluster that we have already created using the script `eks/aws/create-all.sh`.
```bash
./deploy.sh
```
