class User < ApplicationRecord
  before_save { self.email.downcase! }
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  
  has_many :microposts
  has_many :relationships
  has_many :followings, through: :relationships, source: :follow
  has_many :reverses_of_relationship, class_name: 'Relationship', foreign_key: 'follow_id'
  has_many :followers, through: :reverses_of_relationship, source: :user
  #UserモデルからFavorite(中間テーブル)を見た時
  has_many :favorites
  #Userモデルが中間テーブル(favorites)を経由してmicropostモデルに繋がっている
  #micropostsを一度使っているので、favorite_micropostsと別の言い方に変える
  has_many :favorite_microposts, through: :favorites, source: :micropost
  
  def follow(other_user)
    unless self == other_user
      self.relationships.find_or_create_by(follow_id: other_user.id)
    end
  end
  
  def unfollow(other_user)
    relationship = self.relationships.find_by(follow_id: other_user.id)
    relationship.destroy if relationship
  end
  
  def following?(other_user)
    self.followings.include?(other_user)
  end
  
  def feed_microposts
    Micropost.where(user_id: self.following_ids + [self.id])
  end
  
  #Userがお気に入り追加・削除を行うメソッドを定義する
  #参照しているデータは中間テーブル
  def favorite(micropost)
    favorites.find_or_create_by(micropost_id: micropost.id)
  end
  
  def unfavorite(micropost)
    favorite = favorites.find_by(micropost_id: micropost.id)
    favorite.destroy if favorite
  end
  
  #既にお気に入りに追加している Micropost かどうかを調べる処理
  #参照しているデータは中間テーブルを経由したmicropostsテーブル(self.favorite_micropostsにより複数のMicropostを取得)
  def favorited?(micropost)
    self.favorite_microposts.include?(micropost)
  end
end
