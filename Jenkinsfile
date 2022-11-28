pipeline {
	agent any

    stages  {


// Login to Artifactory
 	stage('Login to Artifactory'){
	 		steps {
			//	withcredentials ([usernamePassword(credentialsId: 'dockerartifactorylogin', passwordVariable: 'DOCKER_PWD', usernameVariable: 'DOCKER_USER_NAME')]) {
  				withCredentials([usernamePassword(credentialsId: 'golden_container_image', passwordVariable: 'golden_container_image_password', usernameVariable: 'golden_container_image_user')]) {
				sh '''
	 				if  docker login vscojfrogrhel.vsazure.com/infra-images -u $golden_container_image_user -p $golden_container_image_password
					then
	 					echo "Login to Artifactory (vscojfrogrhel.vsazure.com) is Successful"
	 				else
	 					echo "Login to Artifactory (vscojfrogrhel.vsazure.com) is Failed, please check with Infra team"; exit 1
	 				fi
				  '''
				}
	 			}
 	 }

  // Getting the list of docker images in jenkins machine and removing them
  		stage('Fetching the old images and removing them from the Jenkins server'){
  			steps {
  				catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
  				sh '''
  					echo "fetching the list of docker images in jenkins machine"
  					docker images -a
  					echo "Removing all the images from jenkins machine"
  					docker rmi $(docker images -q) -f > /dev/null 2>&1
  				   '''
  				}
  					}
  			}

  // Pulling the RHEL base image from our artifactory
  		stage('Pulling the RHEL base image from artifactory'){
  			steps {
				sh '''
  					if  docker pull vscojfrogrhel.vsazure.com/rhel-ubi-images/ubi8:latest
					then
  						echo "Able to pull the RHEL base image from Artifactory"
  					else
  						echo "Unable to pull the RHEL base image from Artifactory, please check with Infra team" ; exit 1
  				        fi
				  '''
  				}
  		}

  // AlertManager package check
  		stage('AlertManager package check in the server and if not available download from Artifactory'){
  			steps {
  				script {
  					if ( fileExists('./alertmanager-0.23.0.linux-amd64.tar.gz') ) {
  						echo "AlertManager tar file is already available"
  						}
  					else {
  						echo "There is no tar file"
  						}

  					sh '''
  						wget https://vscojfrog.vsazure.com/artifactory/oc-infra-local/alertmanager-0.23.0.linux-amd64.tar.gz > /dev/null 2>&1
  					   '''

                              		if ( fileExists('./alertmanager-0.23.0.linux-amd64.tar.gz') ) {
  						echo "Able to download the Package"
  						}
  					else {
  						echo "Unable to download the package from Artifactory" 
  					}
  					}
  				}
  		}


  // Untar the AlertManager package
  		stage('Untar the AlertManager package'){
  			steps {
  				sh '''
  					tar -xvf alertmanager-0.23.0.linux-amd64.tar.gz
  				   '''
  				}
  		}

//Building AlertManager image in jenkins machine
		stage('Building Alertmanager image in jenkins machine'){
			steps {
				sh '''
					docker build -t alertmanager .
				  '''
				}
		}


//Fetching the new image in Jenkins machine
  		stage('Fetching the new image in Jenkins machine'){
  			steps{
				script {
                                        IMAGE = sh (
                                        script: "docker images | grep -w alertmanagernp",
                                        returnStdout: true
                                        ).trim()
                                        echo "New Image : ${IMAGE}"
                                        }
  				}
  		}

  //Tagging and pushing the docker image
  		stage('Tagging and pushing the docker image'){
  			steps {
  				sh '''
  					docker tag alertmanager vscojfrogrhel.vsazure.com/infra-images/alertmanagercentralus
  					docker push vscojfrogrhel.vsazure.com/infra-images/alertmanagercentralus
  				    '''
  				}
  			}

//Azure login
                stage('Azure login'){
                        steps {
                                withCredentials([usernamePassword(credentialsId: 'aztenant', passwordVariable: 'azpwd', usernameVariable: 'azuser')]) {
                                withCredentials([usernamePassword(credentialsId: 'azserviceprincipal', passwordVariable: 'azsppwd', usernameVariable: 'azspuser')]) {
                                sh '''
   					echo $azuser
                                        az login --service-principal -u $azspuser -p $azsppwd --tenant $azuser
                                   '''
                                }
				}
                                }
                        }

  //Connect to AKS-cluster
  		stage('Connect to AKS-cluster'){
  			steps {
  				sh '''
					az aks get-credentials --name vs-etocore-aks-centralus-prod --resource-group vs-etocore-centralus-rg
       				   '''
  					}
  				}

  //Deleting the old pods
  		stage('Deleting the old pods'){
  			steps {
				catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
  				sh '''
  					if kubectl scale --replicas=0 deployment/alertmanagernp -n monitoring
     					then
  						echo "Pods are scaled down"

  					else
  						echo "Unable to scale down the pods, pls check if kubelet is running in the server" ; exit 1
					fi

  				   '''
				}
  				}
  		}

  //Delete the script file from Jenkins machine
  		stage('Delete the script file from Jenkins machine'){
  			steps {
  				sh '''
  					rm -f prometheus-deploy.sh
  					rm -f alertmanager-0.23.0.linux-amd64.tar.gz
  					rm -f telnet-0.17-76.el8.x86_64.rpm
  					rm -f iputils-20180629-7.el8.x86_64.rpm
  					rm -f tcpdump-4.9.3-1.el8.x86_64.rpm
  				    '''
  				}
  			}

  //Deploying the new pods from new docker image
  		stage('Deploying the new pods from new docker image') {
  			steps {
  				sh '''
  					kubectl apply -f AlertManagerConfigmap.yaml
					kubectl apply -f AlertTemplateConfigMap.yaml
					kubectl apply -f Deployment.yaml; kubectl apply -f Service.yaml; sleep 25
  					kubectl scale --replicas=1 deployment/alertmanagernp -n monitoring
  				    '''
				}
			}
		stage('Getting the new pods'){
			steps{
				script {
					BUILD_FULL = sh (
    					script: "kubectl get pods -n monitoring | grep -w 'alertmanagernp'| grep -v 'Failed'|grep -v 'Error'| grep -v 'Pending'",
    					returnStdout: true
					).trim()
					echo "New pods are: ${BUILD_FULL}"
  					}
			}
  		}

   }
}
