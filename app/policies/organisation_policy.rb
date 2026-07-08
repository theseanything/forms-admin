class OrganisationPolicy < ApplicationPolicy
  def can_view_organisations?
    user.super_admin?
  end
end
