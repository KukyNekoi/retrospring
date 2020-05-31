class UserController < ApplicationController
  include ThemeHelper

  before_action :authenticate_user!, only: %w(edit update edit_privacy update_privacy edit_theme update_theme preview_theme delete_theme data export begin_export)

  def show
    @user = User.where('LOWER(screen_name) = ?', params[:username].downcase).first!
    @answers = @user.cursored_answers(last_id: params[:last_id])
    @answers_last_id = @answers.map(&:id).min
    @more_data_available = !@user.cursored_answers(last_id: @answers_last_id, size: 1).count.zero?

    if user_signed_in?
      notif = Notification.where(target_type: "Relationship", target_id: @user.active_relationships.where(target_id: current_user.id).pluck(:id), recipient_id: current_user.id, new: true).first
      unless notif.nil?
        notif.new = false
        notif.save
      end
    end

    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end

  # region Account settings
  def edit
  end

  def update
    user_attributes = params.require(:user).permit(:display_name,  :motivation_header, :website, :show_foreign_themes, :location, :bio,
                                                   :profile_picture_x, :profile_picture_y, :profile_picture_w, :profile_picture_h,
                                                   :profile_header_x, :profile_header_y, :profile_header_w, :profile_header_h, :profile_picture, :profile_header)
    if current_user.update_attributes(user_attributes)
      text = t('flash.user.update.text')
      text += t('flash.user.update.avatar') if user_attributes[:profile_picture]
      text += t('flash.user.update.header') if user_attributes[:profile_header]
      flash[:success] = text
    else
      flash[:error] = t('flash.user.update.error')
    end
    redirect_to edit_user_profile_path
  end
  # endregion

  # region Privacy settings
  def edit_privacy
  end

  def update_privacy
    user_attributes = params.require(:user).permit(:privacy_allow_anonymous_questions,
                                                   :privacy_allow_public_timeline,
                                                   :privacy_allow_stranger_answers,
                                                   :privacy_show_in_search)
    if current_user.update_attributes(user_attributes)
      flash[:success] = t('flash.user.update_privacy.success')
    else
      flash[:error] = t('flash.user.update_privacy.error')
    end
    redirect_to edit_user_privacy_path
  end
  # endregion

  # region Lists
  def lists
    @user = User.where('LOWER(screen_name) = ?', params[:username].downcase).first!
    @lists = if current_user == @user
                @user.lists
              else
                @user.lists.where(private: false)
              end.all
  end
  # endregion

  def followers
    @title = 'Followers'
    @user = User.where('LOWER(screen_name) = ?', params[:username].downcase).first!
    @users = @user.cursored_followers(last_id: params[:last_id])
    @users_last_id = @users.map(&:id).min
    @more_data_available = !@user.cursored_followers(last_id: @users_last_id, size: 1).count.zero?
    @type = :friend

    respond_to do |format|
      format.html { render "show_follow" }
      format.js { render "show_follow", layout: false }
    end
  end

  def friends
    @title = 'Following'
    @user = User.where('LOWER(screen_name) = ?', params[:username].downcase).first!
    @users = @user.cursored_friends(last_id: params[:last_id])
    @users_last_id = @users.map(&:id).min
    @more_data_available = !@user.cursored_friends(last_id: @users_last_id, size: 1).count.zero?
    @type = :friend

    respond_to do |format|
      format.html { render "show_follow" }
      format.js { render "show_follow", layout: false }
    end
  end

  def questions
    @title = 'Questions'
    @user = User.where('LOWER(screen_name) = ?', params[:username].downcase).first!
    @questions = @user.cursored_questions(author_is_anonymous: false, last_id: params[:last_id])
    @questions_last_id = @questions.map(&:id).min
    @more_data_available = !@user.cursored_questions(author_is_anonymous: false, last_id: @questions_last_id, size: 1).count.zero?

    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end

  def data
  end

  def edit_theme
  end

  def delete_theme
    current_user.theme.destroy!
    redirect_to edit_user_theme_path
  end

  def update_theme
    update_attributes = params.require(:theme).permit([
      :primary_color, :primary_text,
      :danger_color, :danger_text,
      :success_color, :success_text,
      :warning_color, :warning_text,
      :info_color, :info_text,
      :dark_color, :dark_text,
      :light_color, :light_text,
      :raised_background, :raised_accent,
      :background_color, :body_text, 
      :muted_text, :input_color, 
      :input_text
    ])

    if current_user.theme.nil?
      current_user.theme = Theme.new update_attributes
      current_user.theme.user_id = current_user.id

      if current_user.theme.save
        flash[:success] = 'Theme saved.'
      else
        flash[:error] = 'Theme saving failed. ' + current_user.theme.errors.messages.flatten.join(' ')
      end
    elsif current_user.theme.update_attributes(update_attributes)
      flash[:success] = 'Theme saved.'
    else
      flash[:error] = 'Theme saving failed. ' + current_user.theme.errors.messages.flatten.join(' ')
    end
    redirect_to edit_user_theme_path
  end

  def export
    if current_user.export_processing
      flash[:info] = 'An export is currently in progress for this account.'
    end
  end

  def begin_export
    if current_user.can_export?
      ExportWorker.perform_async(current_user.id)
      flash[:success] = 'Your account is currently being exported.  This will take a little while.'
    else
      flash[:error] = 'Nice try, kid.'
    end

    redirect_to user_export_path
  end
end
