#!/groovy

pipeline {
    agent any
    environment {
        DOCKER_CREDS = credentials('DOCKER_HUB_CREDS')
        IMAGE_NAME = 'antsman/rpi-nodered'
        IMAGE_TAG = "ci-jenkins-$BRANCH_NAME"
        CONTAINER_NAME = "$BUILD_TAG"
        NODE_RED_DOCKER = "https://github.com/node-red/node-red-docker"
        NODE_RED_LOCAL = "node-red-docker"
        NODE_RED_MAKE = "docker-make.sh"
        DOCKERFILE = "Dockerfile.custom"
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
                  sed -i $NODE_RED_MAKE -e 's/OS=alpine/OS=buster/'
                  sed -i $NODE_RED_MAKE -e 's/NODE_VERSION=12/NODE_VERSION=10/'
                  sed -i $NODE_RED_MAKE -e s/testing:node-red-build/\$(echo $IMAGE_NAME | sed 's/\\//\\\\\\//'):$IMAGE_TAG/

                  # Adjust $DOCKERFILE to Debian: use apt-get
                  sed -i $DOCKERFILE -e 's/apk add --no-cache/apt-get update \\&\\& apt-get install -y/'
                  sed -i $DOCKERFILE -e 's/--virtual buildtools//'
                  # hide packages not found
                  sed -i $DOCKERFILE -e 's/iputils//' # ping, traceroute
                  sed -i $DOCKERFILE -e 's/nano//'
                  # adduser
                  # adduser -h /usr/src/node-red -D -H node-red -u 1000
                  # adduser --home /usr/src/node-red --disabled-password --no-create-home --gecos '' --uid 1000 node-red
                  sed -i $DOCKERFILE -e 's/adduser -h/adduser --home/'
                  sed -i $DOCKERFILE -e 's/-D -H/--disabled-password --no-create-home --gecos \"\"/'
                  sed -i $DOCKERFILE -e 's/-u 1000/--uid 1000/'
                  # use apt-get, hide packages not found, add required (for netstat, irsend)
                  sed -i $DOCKERFILE -e 's/build-base linux-headers udev//'
                  sed -i ./scripts/install_devtools.sh -e 's/apk add --no-cache --virtual devtools/apt-get install -y/'
                  sed -i ./scripts/install_devtools.sh -e 's/build-base linux-headers udev/musl net-tools lirc sudo/'
                  # Update from Dockerfile.alpine
                  sed -i $DOCKERFILE -e 's/Dockerfile.alpine/$DOCKERFILE/'

                  cat $NODE_RED_MAKE
                  ./$NODE_RED_MAKE
                """
            }
        }
        stage('TEST') {
            steps {
                sh "docker run -d --rm --name $CONTAINER_NAME $IMAGE_NAME:$IMAGE_TAG"
                // Get nodered, os version in started container, store in version.properties
                sh "./get-versions.sh $CONTAINER_NAME"
                load './version.properties'
                // echo "$NODERED_VERSION"
                // echo "$OS_VERSION"
                echo 'Sleep short, to allow Node-RED to start'
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
                sh "docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:$NODERED_VERSION-$OS_VERSION"

                sh "echo $DOCKER_CREDS_PSW | docker login --username $DOCKER_CREDS_USR --password-stdin"

                sh "docker push $IMAGE_NAME:latest"
                sh "docker push $IMAGE_NAME:$NODERED_VERSION"
                sh "docker push $IMAGE_NAME:$NODERED_VERSION-$OS_VERSION"
            }
        }
    }
    post {
        failure {
            sh "docker rm -f $CONTAINER_NAME"
        }
    }
}
