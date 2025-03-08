# Terraform Hetzner Cloud Talos

## 🎯 About

Get a cheap HA-ready Kubernetes cluster in less than **5 minutes**, with easy configuration setup through simple Terraform variables, 💯 GitOps way !

This opinionated Terraform template will generate a ready-to-go cloud infrastructure through Hetzner Cloud provider, optimized for [Talos](https://www.talos.dev/), the most popular dedicated Kubernetes OS.

## 🚀 Quick start

A valid Talos snapshot, identified by the selector `os=talos` must be available in your Hetzner Cloud account. Go to packer subfolder and build snapashot from here or follow the [official guide](https://www.talos.dev/v1.9/talos-guides/install/cloud-platforms/hetzner/) to generate one. The latest snapshot will be automatically selected by default.

## 📝 License

This project is under license from MIT. For more details, see the [LICENSE](https://adr1enbe4udou1n.mit-license.org/) file.

Made with :heart: by <a href="https://github.com/adr1enbe4udou1n" target="_blank">Adrien Beaudouin</a>
