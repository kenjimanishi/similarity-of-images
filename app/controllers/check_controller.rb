class CheckController < ApplicationController
  protect_from_forgery :except => [:upload_image]

  require "phashion"
  require "dhash-vips"
  # require "open-uri"

  def index
    @image = Image.destroy_all
    ActiveRecord::Base.connection.execute("TRUNCATE images")
  end

  def result
    if params[:image_id]
      ##################################
      # Download Image
      ##################################
      # first_image_path = 'https://XXXXXXX'
      # open(first_image_path) { |image|
      #   File.open(first_image,"wb") do |file|
      #     file.puts image.read
      #   end
      # }
      image_id = params[:image_id].split(",")
      if image_id.size === 2
        @image_h = Hash.new { |h,k| h[k] = {} }
        file_path_r = Array.new
        image_id.each { |id|
          if Image.exists?(id: id)
            image = Image.find(id)
            @image_h[image.id]['image'] = image
            @image_h[image.id]['file_name'] = File.basename(image.file.path)
            file_path_r << getFilePath(image);
          end  
        }

        if params[:type] === '0'
          ##################################
          # Use of dhash-vips（IDHash）
          ##################################
          @type = 'libvips(IDHash)'
          calcIDHash(file_path_r)
          
        elsif params[:type] === '1'
          ##################################
          # Use of dhash-vips（DHash）
          ##################################
          @type = 'libvips(DHash)'
          calcDHash(file_path_r)
        else
          ##################################
          # Use of Phashion
          ##################################
          @type = 'ImageMagick'
          calcPhashion(file_path_r)
        end
      else
        logger.warn('[Invalid image_id]: ' + params[:image_id].inspect)
        redirect_to check_index_path, flash: {danger: 'Invalid Data (image_id)'}
      end
    else
      redirect_to check_index_path
    end
  end

  def upload_image
    image = Image.new params.require(:image).permit(:file)
    begin
      image.save!
      result = image
    rescue => e
      logger.error('[upload_image]:' + e.inspect)
      result = false
    end
    render status: 200, json: result, nothing: true
  end

  def delete_image
    if Image.exists?(id: params[:image_id])
      image = Image.find(params[:image_id])
      begin
        image.destroy!
        result = image
      rescue => e
        logger.error('[delete_image]:' + e.inspect)
        result = false
      end
    else
      result = true
    end
    render status: 200, json: result, nothing: true
  end

  private
    def getFilePath(image)
      tmp_file_path = image.file.url.gsub('/uploads/image', 'public/uploads/image')
      file_path = URI.decode(tmp_file_path).force_encoding('UTF-8')
      return file_path
    end

    def calcIDHash(file_path_r)
      hash1 = DHashVips::IDHash.fingerprint file_path_r[0]
      hash2 = DHashVips::IDHash.fingerprint file_path_r[1]
      @hamming_distance = DHashVips::IDHash.distance hash1, hash2
      decision(@hamming_distance)
    end

    def calcDHash(file_path_r)
      hash1 = DHashVips::DHash.calculate file_path_r[0]
      hash2 = DHashVips::DHash.calculate file_path_r[1]
      @hamming_distance = DHashVips::DHash.hamming hash1, hash2
      decision(@hamming_distance, 10, 20)
    end

    def calcPhashion(file_path_r)
      hash1 = Phashion::Image.new(file_path_r[0])
      hash2 = Phashion::Image.new(file_path_r[1])
      @hamming_distance = hash1.distance_from(hash2)
      decision(@hamming_distance)
    end

    def decision(hamming_distance, threshold1=15, threshold2 = 25)
      if hamming_distance == 0
        @result_message = 'Images are perfect matching'
        @bg_color = 'bg-success'
      elsif hamming_distance < threshold1
        @result_message = 'Images are very similar'
        @bg_color = 'bg-info'
      elsif hamming_distance < threshold2
        @result_message = 'Images are slightly similar'
        @bg_color = 'bg-warning'
      else
        @result_message = 'Images are different'
        @bg_color = 'bg-danger'
      end
    end

end
