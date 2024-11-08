Argo Suite Examples Repo
========================

This repo contains an example ArgoCD and Argo Workflow example that shows how run
ArgoCD, Argo Events, Argo Notifications and Argo Workflows.

To use this example, you will need to be experienced with Kubernetes, Docker
and GitHub actions.

The example uses public Docker images that have been published to a custom
Docker CR. As such, if you wish to modify these images, you will need to define
your own Dockerfiles. The source for these Dockerfiles is [here](https://github.com/tpayne/kubernetes-examples/tree/main/docker-files)

Pre-requisites
--------------
To be able to use this example, you will have to do the following: -
- Install `kubectl`, `argocd` and `argo`
- Admin access to a Kubernetes system
- Install a Kubernetes system with an Nginx Ingress controller (or use `deploycontroller.sh` to install a pre-canned AKS or GCP system)

```console
    ./deploycontroller.sh -t azure
```
```console
    ./deploycontroller.sh -t gcp \
      -p <projectId> \
      -z europe-west1-c
```
- Create an Argo install based on [Argo-autopilot](https://github.com/tpayne/argocd-autopilot.git). This uses AKS (Azure) by default, but could be modified to use GKE or similar system
- If you forked this repo, you will need to update all the YAML files to refer to your new repo and or branch

Terraform Setup
---------------
If you are familiar with Terraform and setting up the demo to work on GCP, there is a Terraform module created in the [Terraform sub-directory](https://github.com/tpayne/argo-suite-samples/blob/main/terraform/GCP/README.md) that will fully spin up a GKE deployment with Argo installed into it.

You will need to review the TF module and make changes as appropriate as it is only a demo configuration and subject to WIP updates.

Running the Demos
-----------------
The first thing you will need to do before running the demos, is to modify
the host alias used for ingress access. To do this, modify the following files.

```console
    cd examples/simple
    config/monitoredRepos/gitops-deploy.event-source.yaml
    config/monitoredRepos/gitops-deploy-workflow-templates.ingress.yaml
```

When modifying the `ingress` controller and you are using `Nginx`, it is recommended
that you set the host to something like `frontend.<externalIP>.nip.io` (see notes below
for more information for managing externalIP).

You will also need to review and modify all the files that reference hostnames. These are

```console
    examples/simple/config/monitoredRepos/gitops-deploy-workflow-templates.ingress.yaml
    examples/simple/config/monitoredRepos/gitops-deploy.event-source.yaml
    examples/simple/helm/generic/values-ghsvc.yaml
    examples/simple/workflows/generic/workflow-templates/cd-promote-template.yaml
```

Failure to do so will cause the demo to fail.

If you want to run the demo from a branch of the main repo, then you will need to
modify the `targetRevision` value in `examples/simple/workflows/monitor-app.yaml`

Once the above files are modified and committed to the repo, you can then run the following.

This first command block will start up the two Argo GUI (ArgoCD and
ArgoWorkflows) services. To connect to these GUIs, use the ports: -

- 8080 - For ArgoCD
- 2746 - For Argo Workflows

You may need to run these with `sudo` depending on how the security is setup.

```console
    # Start up ArgoCD server locally if needed - https://localhost:8080/
    kubectl port-forward -n argocd svc/argocd-server 8080:80

    # Start up the argo workflow gui if needed - https://localhost:2746/
    argo server -n argocd --auth-mode=server -k --namespaced --loglevel=warn
```

Note - You will need to have the ArgoCD server running locally first.

To get the ArgoCD client configured, you can do the following.

```console
    argoPwd=$(kubectl get secret argocd-initial-admin-secret \
      -n argocd -o jsonpath="{.data.password}" | base64 -d)
    argocd login localhost:8080 --insecure --username admin \
      --password "${argoPwd}"
```

Then you can setup the demo projects by running the following.

(Note - You will need to have the ArgoCD server running locally to generate a token).

```console
    pushd examples/simple
    kubectl delete -n argocd -f workflows/monitor-app.yaml
    kubectl apply -n argocd -f workflows/monitor-app.yaml
    popd
```

You do not need to perform the following steps if you installed Argo using the TF module referenced above.

```console
    argoToken=$(argocd account generate-token --account argorunner)
    kubectl create secret \
      generic argocd-token \
      --from-literal=token=${argoToken} \
      --dry-run=client \
      --save-config -o yaml | kubectl apply -f - -n argocd

    #
    # The following will need to be run with customised values. It refers to any commits
    # made to controlled repos, so please use appropriate values
    #
    # <PAT>     = Custom PAT token
    # <ghuser>  = Custom GH user
    # <ghemail> = Custom GH user commit email. Try using the @noreply versions from GH,
    #             e.g. USERNAME@users.noreply.github.com
    #

    PAT=<PAT>
    GHUSER=<ghuser>
    GHEMAIL=<ghemail>
    kubectl create secret \
      generic github-token \
      --from-literal=token=$PAT \
      --from-literal=user=$GHUSER \
      --from-literal=email=$GHEMAIL \
      --dry-run=client \
      --save-config -o yaml | kubectl apply -f - -n argocd
```

You will then need to setup an email account (gmail) and edit the `argocd-notifications-secret` secret to add the following...
- `email-username=<email.addr>`
- `email-password=<googleAppPasswd>`

`<googleAppPasswd>` are generated once 2-step verification is enabled and
you can create an AppPassword using a custom (or other) type.

Once these are set, then edit the `app.pipeline.yaml` to use the email that you have setup.

Once this is done, you will have an ArgoCD and Argo Workflow system setup that
will initiate a chained deployment from DEV -> QA -> SIT -> PREPROD-> PROD
that will be triggered whenever a change is made to a file in the directories

```console
    examples/simple/helm/dev
    examples/simple/helm/qa
    examples/simple/helm/sit
    examples/simple/helm/preprod
    examples/simple/helm/prod
```

If you change a file in `examples/simple/helm/dev` for example, that change
will be promoted through all the other environments as well.

Linking up to GitHub
--------------------
If you wish to link this demo system upto GitHub Actions, then you will need
to modify the following file and commit it to your repo.

[examples/simple/config/monitoredRepos/gitops-deploy.event-source.yaml](https://github.com/tpayne/argo-suite-samples/blob/main/examples/simple/config/monitoredRepos/gitops-deploy.event-source.yaml)

To register the repos you want to monitor.

```yaml
  github:
    github-reposrc:
      events:
        - push
      repositories:
        - owner: <owner>
          names:
            - <repoName>
            - <repoName>
```

For example.

```yaml
  github:
    github-reposrc:
      events:
        - push
      repositories:
        - owner: tpayne
          names:
            - argo-suite-samples
```

This will create a webhook in these GitHub repos that will link back to your
Argo installation via an Ingress. You will need to go into your Webhook settings
in your repo(s) and ensure the webhook is accessable and works.

If it does not GitHub `ping` correctly, then you will need to work out why the
Ingress is inaccessible. Usual reasons would be things like
- Firewall rules
- Malconfigured or unsupported Ingress controller (AGIC does not work)
- Private IPs or restricted CIDR ranges (GitHub needs to access the Ingress)

Once the webhook is working, you will need to modify your GitHub action to
include something like the following...

```yaml
  update-dev-manifest:
    name: Update Dev deployment manifest
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'push'

    steps:
      - name: Update GitOps deployment manifest values
        uses: tpayne/github-actions/productmanifest@main
        with:
          gitops-repo-url: https://github.com/tpayne/kubernetes-examples
          manifest-file: gitops/Argocd/examples/simple/helm/dev/values-releaseversions.yaml
          github-username: ${{ github.actor }}
          github-token: ${{ secrets.GT_TOKEN }}
          github-email: ${{ github.actor }}@users.noreply.github.com
          image-list: github-service:${{ needs.build.outputs.dotnet7-image }}
          image-tag: ${{ needs.build.outputs.dotnet7-tag }}
```

This sample comes from this [GitHub Action](https://github.com/tpayne/lang-examples/blob/master/.github/workflows/main.yml)

Please see [here](https://github.com/tpayne/github-actions/blob/main/productmanifest/README.md) for more details.

This custom GitHub action uses a shell script to update a Helm manifest file which works as the SBOM. This manifest
format is consistent with the examples used [here](https://github.com/tpayne/argo-suite-samples/blob/main/examples/simple/helm/dev/values-releaseversions.yaml)

Notes
-----
* To get the LoadBalancer IP for Nginx, you can do...

```console
   kubectl get svc/ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

* The Nginx frontend hostname should be `frontend.INGRESS_IPADDR.nip.io` using `-`, rather than `.`

Some Useful Commands
--------------------
The following are some useful `argo` commands to help debug operations

```console
    argo list -n argocd
    argo resubmit <workflowId> -n argocd --watch --log
    argo watch <workflowId> -n argocd
    argo logs <workflowId> -n argocd
    kubectl get apps -n argocd -w | grep pipeline
    kubectl get wf -n argocd -w | grep promote
    kubectl get app -n argocd \
      -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.health}{"\n"}{end}'
```

Liability Warning
-----------------
The contents of this repository (documents and examples) are provided “as-is”
with no warrantee implied or otherwise about the accuracy or functionality of
the examples.

You use them at your own risk. If anything results to your machine or environment
or anything else as a result of ignoring this warning, then the fault is yours
only and has nothing to do with me.
