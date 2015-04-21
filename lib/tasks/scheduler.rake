desc "Check Pine Box"
task :check_pine_box => :environment do
  ApplicationHelper.check_pine_box
end

desc "Check Chuck's 85"
task :check_chucks_85 => :environment do
  ApplicationHelper.check_chucks_85
end

desc "Check Chuck's CD"
task :check_chucks_cd => :environment do
  ApplicationHelper.check_chucks_cd
end