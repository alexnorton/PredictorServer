SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    primary.dom_class = 'nav navbar-nav'
    primary.item :users, 'Users', '/users'
    primary.item :trajectories, 'Trajectories', '/trajectories'
  end
end