# OpenShift JMeter Image

This was derived from [Woh Shon's JMeter image](https://hub.docker.com/r/wohshon/jmeter).

To install the image on OpenShift, run

```
make imagestream
```

This will create a `jmeter` imagestream in the `openshift` namespace. The image can be used as-is or it can be used as a source-to-image builder.

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

After the test has completed, the results will be available at `http://route.to.pod`.

There are 2 ways to get test plans into the pod: through a source-to-image build or by mounting them as a configmap.

To get the test plan into the image using source-to-image (assuming you have deployed the demo),

```
oc project demo

oc set volume \
  --remove \
  --name testplan \
  dc/jmeter

oc new-build \
  --name=my-jmeter \
  --binary \
  --image-stream=jmeter

oc start-build \
  --follow \
  --from-file=testplan/webserver.jmx \
  my-jmeter

# Patch the deploymentconfig to use the new JMeter image
oc patch \
  dc/jmeter \
  --type=json \
  -p='[{"op":"replace","path":"/spec/triggers/1/imageChangeParams/from/name","value":"my-jmeter:latest"},{"op":"replace","path":"/spec/triggers/1/imageChangeParams/from/namespace","value":"demo"}]'

oc set image dc/jmeter jmeter=my-jmeter:latest --source=imagestreamtag

oc rollout latest dc/jmeter
```

To get the test plan to mount as a configmap, look at the `demo` target in the `Makefile`.
