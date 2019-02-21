include env.mk

DIRS = \
	master \
	slave 

build:
	for d in $(DIRS); do \
		$(MAKE) -C $$d build || exit 1; \
	done

push:
	for d in $(DIRS); do \
		$(MAKE) -C $$d push || exit 1; \
	done

deploy:
	for d in $(DIRS); do \
		$(MAKE) -C $$d deploy || exit 1; \
	done
	echo "Congratulations, Jenkins is deployed at http://${JENKINS_HOST_PORT}/jenkins !!!!"

stop:
	for d in $(DIRS); do \
		$(MAKE) -C $$d stop || exit 1; \
	done


print-% : ; @echo $* = $($*)
