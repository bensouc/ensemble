# Belt.all.each do |belt|
#   if belt.domain_id.nil?
#   grade = belt.student.grade
#   domain = Domain.find_by(grade: grade, name: belt.name_domain )
#   belt.update!(domain: domain)
#   p belt
#   end
# end



# [1774,
#  1780,
#  1784,
#  1787,
#  1798,
#  1800,
#  1804,
#  1810,
#  1815,
#  1819,
#  1903,
#  1910,
#  1912,
#  1918,
#  1919,
#  1921,
#  1922,
#  1924,
#  1927,
#  1928,
#  1929,
#  1930,
#  1931,
#  1933,
#  1935,
#  1936,
#  1937,
#  1938,
#  1939,
#  1940,
#  1942,
#  1943,
#  1944,
#  1945,
#  1946,
#  1948,
#  1964,
#  1977,
#  1984].each do |skill_id|
#   skill = Skill.find(skill_id)
#   domain = Domain.find_by(grade: Grade.find(10), name: skill.name_domain)
#   p skill.update!(domain: domain)
#  end

#  [
#   3836,
# 3839,
# 3842,
# 3851,
# 3852,
# 3856,
# 3861,
# 3866,
# 3869,
# 3949,
# 3954,
# 3955,
# 3957,
# 3958,
# 3960,
# 3962,
# 3963,
# 3964,
# 3965,
# 3966,
# 3969,
# 3970,
# 3971,
# 3972,
# 3973,
# 3974,
# 3975,
# 3976,
# 3977,
# 3978,
# 3979,
# 3981,
# 3988,
# 4011,
# 4018,
# 4150,
# 4167,
# 4169,
# 4172,
# 4176
#  ].each do |skill_id|
#   skill = Skill.find(skill_id)
#   domain = Domain.find_by(grade: Grade.find(5), name: skill.name_domain)
#   p skill.update!(domain: domain)
#  end
