# OpenShift JMeter Image

This was derived from [Woh Shon's JMeter image](https://hub.docker.com/r/wohshon/jmeter).


## Installing the imagestream

To install the image on OpenShift, run

```
make imagestream
```

This will create a `jmeter` imagestream in the `openshift` namespace. The image can be used as-is or it can be used as a source-to-image builder.


## Installing the demo

To deploy a demo, run

```
make demo
```

Please note that you should run `make imagestream` before running `make demo`.

The image expects JMeter `.jmx` test plans to be in the `/opt/jmeter/testplan` directory.

Once the pod is up, you can trigger JMeter to run by accessing `http://route.to.pod/cgi-bin/trigger`. To trigger the demo deployment to run, execute

```
make trigger
```

After the test has completed, the results will be available at `http://route.to.pod`. Run `make webserver` to open a web browser to the web server.

The demo deploys a `jmeter` deploymentconfig and a test web server. A test plan runs a short HTTP test against the test web server. The test plan is created as a configmap and is mounted as a volume in the `jmeter` deploymentconfig.


## Getting your test plans into the image

There are 2 ways to get test plans into the pod: through a source-to-image build or by mounting them as a configmap.

### Using source-to-image

To get the test plan into the image using source-to-image,

```
oc new-build \
  --name=my-jmeter \
  --binary \
  --image-stream=jmeter

oc start-build \
  --follow \
  --from-file=testplan/webserver.jmx \
  my-jmeter

oc new-app \
  -f jmeter_template.yaml \
  -p NAMESPACE=$(oc project -q) \
  -p IMAGESTREAMTAG=my-jmeter:latest
```

### Using a configmap

To get the test plan to mount as a configmap,

1. Create the test plan as a configmap:

	```
	oc create cm testplan --from-file=testplan/webserver.jmx
	oc label cm/testplan app=jmeter
	```

1. Provision JMeter:

	```
	oc new-app -f jmeter_template.yaml
	```

1. Mount the test plan:

	```
	oc set volume \
	  dc/jmeter \
	  --add \
	  --name=testplan \
	  -c jmeter \
	  -t configmap \
	  --configmap-name=testplan \
	  -m /opt/jmeter/testplan
	```


### Uninstalling

To remove the JMeter deployment,

```
oc delete all -l app=jmeter
oc delete cm -l app=jmeter
```

To remove the JMeter imagestream,

```
oc delete -n openshift is/jmeter
```
