class InvitationsController < ApplicationController
  allow_unauthenticated_access only: %i[ show update ]
  before_action :set_invitation, only: %i[ show update ]

  def create
    unless Current.user.owner?
      return redirect_to root_path, alert: "No tenés permiso para generar invitaciones"
    end

    invitation = Current.user.complejo.invitations.create!(invited_by: Current.user)
    redirect_to configuracion_path, notice: "Link de invitación: #{invitation_url(invitation.token)}"
  end

  def show
    @user = @invitation.complejo.users.build if @invitation&.redeemable?
  end

  def update
    if @invitation&.redeemable?
      @user = @invitation.complejo.users.build(user_params)
      @user.role = :employee

      if @user.save
        @invitation.update!(used_at: Time.current)
        start_new_session_for(@user)
        redirect_to root_path, notice: "Cuenta creada"
      else
        render :show, status: :unprocessable_entity
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_invitation
      @invitation = Invitation.find_by(token: params[:token])
    end

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
