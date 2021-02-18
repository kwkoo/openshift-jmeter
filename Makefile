PROJ=demo

BASE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: docker imagestream cleanimagestream demo cleandemo trigger webserver logs

docker:
	@docker build -t jmeter $(BASE)/docker

imagestream: cleanimagestream
	oc new-build \
	  -n openshift \
	  --name=jmeter \
	  --binary \
	  --strategy=docker
	oc start-build \
	  -n openshift \
	  --from-dir=$(BASE)/docker \
	  --follow \
	  jmeter
	oc delete -n openshift bc/jmeter

cleanimagestream:
	-oc delete -n openshift is/jmeter

demo: cleandemo
	@if [ `oc get istag/jmeter:latest -n openshift 2>/dev/null 1>/dev/null` -ne 0 ]; then \
	  echo "jmeter imagestream has not been installed - run 'make imagestream' first"; \
	  exit 1; \
	fi

	oc new-project $(PROJ) || oc project $(PROJ)

	# Deploy demo test target
	oc create cm web-html \
	  -n $(PROJ) \
	  --from-file=$(BASE)/html/index.html
	oc label cm/web-html -n $(PROJ) app=web
	oc new-app \
	  -n $(PROJ) \
	  --name web \
	  httpd
	oc set volume \
	  deploy/web \
	  -n $(PROJ) \
	  --add \
	  --name=html \
	  -t configmap \
	  --configmap-name=web-html \
	  -m /var/www/html
	
	# Create test plan as configmap
	oc create cm testplan \
	  -n $(PROJ) \
	  --from-file=$(BASE)/testplan/webserver.jmx
	oc label cm/testplan -n $(PROJ) app=jmeter

	oc new-app -n $(PROJ) -f $(BASE)/jmeter_template.yaml

	oc set volume \
	  dc/jmeter \
	  -n $(PROJ) \
	  --add \
	  --name=testplan \
	  -c jmeter \
	  -t configmap \
	  --configmap-name=testplan \
	  -m /opt/jmeter/testplan

	oc expose svc/jmeter

cleandemo:
	# Clean up old artifacts
	-oc delete -n $(PROJ) all -l app=web
	-oc delete -n $(PROJ) is/web
	-oc delete -n $(PROJ) all -l app=jmeter
	-oc delete -n $(PROJ) cm -l app=jmeter
	-oc delete -n $(PROJ) cm -l app=web

trigger:
	curl http://`oc get route/jmeter -n $(PROJ) -o jsonpath='{.spec.host}'`/cgi-bin/trigger

webserver:
	open http://`oc get route/jmeter -n $(PROJ) -o jsonpath='{.spec.host}'`

logs:
	oc logs -n $(PROJ) --all-containers -f `oc get po -n $(PROJ) -l deploymentconfig=jmeter -o name`