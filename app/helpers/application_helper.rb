module ApplicationHelper
  def breadcrumb(text, path = nil)
    if path
      link_to text, path, style: 'color: #5C6AC4; text-decoration: none; font-weight: 500;'
    else
      content_tag :span, text, style: 'color: #202223; font-weight: 500;'
    end
  end

  def breadcrumb_separator
    content_tag :span, '›', style: 'color: #babfc3; font-weight: 400;'
  end

  def shopify_path_params
    {
      shop: params[:shop],
      host: params[:host],
      embedded: params[:embedded],
      id_token: params[:id_token]
    }
  end
end
