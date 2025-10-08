Ansible bootstrap

This project uses Ansible to provision Minikube and Rancher locally. To run the playbook you need Ansible and the Kubernetes collections.

Install Ansible and required collections (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip
python3 -m pip install --user ansible
# ensure ~/.local/bin is in your PATH, or install system-wide with 'pip3 install ansible'

# Install collections
ansible-galaxy collection install -r Ansible/requirements.yml
```

Then run:

```bash
cd Ansible
ansible-playbook playbooks/site.yml -K
```

If `ansible-playbook` is not found, ensure you installed Ansible and that `~/.local/bin` is in your PATH.
