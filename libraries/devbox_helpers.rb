def mkdir_p(dir)
  directory dir do
    action :create
    owner $username
    recursive true
  end
end

