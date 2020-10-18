#!/groovy

pipeline {
    agent any
    environment {
        DOCKER_CREDS = credentials('DOCKER_HUB_CREDS')
        IMAGE_NAME = 'antsman/rpi-nodered'
        IMAGE_TAG = "ci-jenkins-$BRANCH_NAME"
        CONTAINER_NAME = "$BUILD_TAG"
        NODE_RED_DOCKER = 'https://github.com/node-red/node-red-docker'
        NODE_RED_LOCAL = 'node-red-docker'
        NODE_RED_MAKE = 'docker-debian.sh'
        DOCKERFILE = 'Dockerfile.debian'
        DEVTOOLS = './scripts/install_devtools.sh'
    }
    stages {
        stage('BUILD') {
            steps {
                sh """
                  rm -rf $NODE_RED_LOCAL
                  git clone $NODE_RED_DOCKER $NODE_RED_LOCAL
                  cd $NODE_RED_LOCAL/docker-custom

                  # Change the build arguments as needed
                  sed -i $NODE_RED_MAKE -e 's/ARCH=amd64/ARCH=arm32v7/'
                  ## sed -i $NODE_RED_MAKE -e 's/OS=alpine/OS=buster-slim/'
                  # sed -i $NODE_RED_MAKE -e 's/NODE_VERSION=12/NODE_VERSION=10/'
                  sed -i $NODE_RED_MAKE -e s/testing:node-red-build/\$(echo $IMAGE_NAME | sed 's/\\//\\\\\\//'):$IMAGE_TAG/

                  # BASE
                  # Adjust $DOCKERFILE to Debian: use apt-get
                  ## sed -i $DOCKERFILE -e 's/apk add --no-cache/apt-get update \\&\\& apt-get install -y -qq --no-install-recommends/'
                  # cut packages not found
                  ## sed -i $DOCKERFILE -e 's/iputils//' # ping, traceroute
                  ## sed -i $DOCKERFILE -e 's/nano//'
                  # adduser
                  # adduser -h /usr/src/node-red -D -H node-red -u 1000
                  # adduser --home /usr/src/node-red --disabled-password --no-create-home --gecos '' --uid 1000 node-red
                  ## sed -i $DOCKERFILE -e 's/adduser -h/adduser --home/'
                  ## sed -i $DOCKERFILE -e 's/-D -H/--disabled-password --no-create-home --gecos \"\"/'
                  ## sed -i $DOCKERFILE -e 's/-u 1000/--uid 1000/'

                  # BUILD
                  # use apt-get, build-essential
                  # sed -i $DOCKERFILE -e 's/--virtual buildtools build-base linux-headers udev/build-essential/'

                  # RELEASE
                  # Update from Dockerfile.debian
                  ## sed -i $DOCKERFILE -e 's/Dockerfile.alpine/$DOCKERFILE/'
                  # Install devtools & Clean up
                  ## sed -i $DEVTOOLS -e 's/apk add --no-cache/apt-get install -y -qq --no-install-recommends/'
                  ## sed -i $DEVTOOLS -e 's/--virtual devtools build-base linux-headers udev/build-essential net-tools procps lirc/'
                  sed -i $DOCKERFILE -e 's/build-essential python-dev/build-essential python-dev net-tools procps lirc/'
                  # Clean up apt cache
                  sed -i $DOCKERFILE -e 's/rm -r \\/tmp\\/*/rm -r \\/tmp\\/* \\&\\& rm -rf \\/var\\/lib\\/apt\\/lists\\/*/'

                  # cat $NODE_RED_MAKE
                  ./$NODE_RED_MAKE
                """
            }
        }
        stage('TEST') {
            steps {
                sh "docker run -d --rm --name $CONTAINER_NAME $IMAGE_NAME:$IMAGE_TAG"
                // Get nodered, node, os version in started container, store in version.properties
                sh "./get-versions.sh $CONTAINER_NAME"
                load './version.properties'
                echo 'Sleep short, allow Node-RED to start'
                sh 'date'
                sleep 5
                sh "docker exec -t $CONTAINER_NAME netstat -tlp | grep :1880 | grep node-red"
                sh "time docker stop $CONTAINER_NAME"
            }
        }
        stage('PUSH') {
            when {
                branch 'master'
            }
            steps {
                sh "docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest"
                sh "docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:$NODERED_VERSION"
                sh "docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:$NODERED_VERSION-node-$NODE_VERSION"
                sh "docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:$NODERED_VERSION-node-$NODE_VERSION-$OS_VERSION"

                sh "echo $DOCKER_CREDS_PSW | docker login --username $DOCKER_CREDS_USR --password-stdin"

                sh "docker push $IMAGE_NAME:latest"
                sh "docker push $IMAGE_NAME:$NODERED_VERSION"
                sh "docker push $IMAGE_NAME:$NODERED_VERSION-node-$NODE_VERSION"
                sh "docker push $IMAGE_NAME:$NODERED_VERSION-node-$NODE_VERSION-$OS_VERSION"
            }
        }
    }
    post {
        failure {
            sh "docker rm -f $CONTAINER_NAME"
        }
    }
}
