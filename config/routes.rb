Rails.application.routes.draw do
  root 'check#index'
  match 'check/index', via: [:get, :post]
  match 'check/result', via: [:get, :post]
  match 'check/upload_image', via: [:post]
  match 'check/delete_image', via: [:delete]
end
