devbox = $devbox = node.attribute?('devbox')

if devbox
  username = $username = node.devbox.username
  userhome = $userhome = "/home/#{username}"
  projhome = $projhome = userhome

  user username do
    action :create
    home userhome
    shell "/bin/bash"
    comment username
    supports(:manage_home => true)
  end

  sudoers = [username]
  sudoers << "vagrant" if devbox
  node.authorization.sudo.users = sudoers
  node.authorization.sudo.passwordless = true
  node.authorization.sudo.sudoers_defaults = [
    # @@ (zah) This is quite messy, isn't there a better way?
    'secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/vagrant_ruby/bin/"',
    'env_reset',
    'exempt_group=admin'
  ] 

  include_recipe "sudo"

  mkdir_p "#{userhome}/.ssh"

  execute "configure git" do
    command %[su #{username} -l -c 'git config --global user.name "#{node.devbox.fullname}" && git config --global user.email "#{node.devbox.email}"'] 
  end

  file "#{userhome}/.ssh/id_rsa" do
    mode "0600"
    user username
    content node.devbox.ssh_private_bytes
  end

  ["id_rsa.pub", "authorized_keys"].each do |keyfile|
    file "#{userhome}/.ssh/#{keyfile}" do
      mode "0600"
      user username
      content node.devbox.ssh_public_bytes
      action :create
    end
  end

  template "#{userhome}/.ssh/git_ssh_wrapper" do
    mode "700"
    owner username
    source "git_ssh_wrapper.sh.erb"
    variables :userhome => userhome
    action :create
  end
end
