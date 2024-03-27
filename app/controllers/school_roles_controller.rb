class SchoolRolesController < ApplicationController
  def create
    @user = current_user
    @school = School.find_by(code: params[:new_sub][:school_code])
    authorize @school
    @school_role = SchoolRole.new(user: @user, school: @school)
    @school_role.save

    redirect_to dashboard_path, notice: "Vous avez rejoint l'ecole/groupe #{current_user.school.name}"
  end
end
