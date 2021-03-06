#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Profile < ActiveRecord::Base
  require File.join(Rails.root, 'lib/diaspora/webhooks')
  include Diaspora::Webhooks
  include ROXML

  xml_attr :diaspora_handle
  xml_attr :first_name
  xml_attr :last_name
  xml_attr :image_url
  xml_attr :image_url_small
  xml_attr :image_url_medium
  xml_attr :birthday
  xml_attr :gender
  xml_attr :bio
  xml_attr :searchable

  before_save :strip_names
  after_validation :strip_names

  validates_length_of :first_name, :maximum => 32
  validates_length_of :last_name,  :maximum => 32
  validates_format_of :first_name, :with => /\A[^;]+\z/, :allow_nil => true
  validates_format_of :last_name, :with => /\A[^;]+\z/, :allow_nil => true

  attr_accessible :first_name, :last_name, :image_url, :image_url_medium,
    :image_url_small, :birthday, :gender, :bio, :searchable, :date

  belongs_to :person

  def subscribers(user)
    Person.joins(:contacts).where(:contacts => {:user_id => user.id, :pending => false})
  end

  def receive(user, person)
    person.profile = self
    person.save
    self
  end

  def diaspora_handle
    #get the parent diaspora handle, unless we want to access a profile without a person
    (self.person) ? self.person.diaspora_handle : self[:diaspora_handle]
  end

  def image_url(size = :thumb_large)
    result = if size == :thumb_medium && self[:image_url_medium]
               self[:image_url_medium]
             elsif size == :thumb_small && self[:image_url_small]
               self[:image_url_small]
             else
               self[:image_url]
             end
    result || '/images/user/default.png'
  end

  def image_url= url
    return image_url if url == ''
    if url.nil? || url.match(/^https?:\/\//)
      super(url)
    else
      super(absolutify_local_url(url))
    end
  end

  def image_url_small= url
    return image_url if url == ''
    if url.nil? || url.match(/^https?:\/\//)
      super(url)
    else
      super(absolutify_local_url(url))
    end
  end

  def image_url_medium= url
    return image_url if url == ''
    if url.nil? || url.match(/^https?:\/\//)
      super(url)
    else
      super(absolutify_local_url(url))
    end
  end

  def date= params
    if ['month', 'day'].all? { |key| params[key].present?  }
      params['year'] = '1000' if params['year'].blank?
      date = Date.new(params['year'].to_i, params['month'].to_i, params['day'].to_i)
      self.birthday = date
    elsif [ 'year', 'month', 'day'].all? { |key| params[key].blank? }
      self.birthday = nil
    end
  end

  protected

  def strip_names
    self.first_name.strip! if self.first_name
    self.last_name.strip! if self.last_name
  end

  private
  def absolutify_local_url url
    pod_url = AppConfig[:pod_url].dup
    pod_url.chop! if AppConfig[:pod_url][-1,1] == '/'
    "#{pod_url}#{url}"
  end
end
