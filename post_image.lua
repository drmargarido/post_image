-- Random name generation configuration
local printable_chars = require "printable_chars".printable_chars
local blacklist_chars = require "printable_chars".blacklist_chars
local chars_to_blacklist = {
    "\"", "'", "?", "<", ">", ".", "#", "$", "´", "`",
    ":", "*", "^", ";", "+", "@", " ", ")", "}", "{", "~",
    "(", "[", "]", "\\", "%", "!", "=", "&", "|", "/", ","
}
blacklist_chars(chars_to_blacklist)

-- Image handling library
local magick = require "magick"

-- Default formats whitelist
local ALLOWED_IMAGE_EXTENSIONS = {
    [".jpg"] = true,
    [".png"] = true,
    [".jpeg"] = true,
    [".bmp"] = true
}

local media_path = "./"


--[[    Private helpers     ]]--
local function get_filename_format(filename)
    local extension = filename:match("^.+(%..+)$")
    if extension then
        extension = string.lower(extension)
    end

    return extension
end


local function get_random_filename()
    -- Read random chars from /dev/urandom to generate an id
    local urandom = io.open("/dev/urandom", "r")
    local random_data = urandom:read(32)
    local random_id = printable_chars(random_data)
    urandom:close()

    return string.format("%s%s", os.time(), random_id)
end


--[[    Configuration methods   ]]--

-- Define the image formats whitelist
local function set_allowed_formats(formats)
    local new_formats = {}
    for i = 0, #formats do
        new_formats[formats[i]] = true
    end

    ALLOWED_IMAGE_EXTENSIONS = new_formats
end

-- Set the folder where the images will managed
local function set_base_folder(path)
    media_path = path or "./"
end


--[[    Image controlling methods   ]]--
local function get_image(image_name, image_content)
    local image = {}

    image.name = get_random_filename()
    image.extension = get_filename_format(image_name)

    if ALLOWED_IMAGE_EXTENSIONS[image.extension] then
        local _image = magick.load_image_from_blob(image_content)

        if _image then
            image.width  = _image:get_width()
            image.height = _image:get_height()
        else
            print("The received image has no content")
            return nil
        end
    else
        print("Invalid logo image received")
        return nil
    end

    image.content = image_content

    -- Filesystem paths
    image.full_path = image.name .. image.extension

    return image
end

local function save_image(image)
    local file = io.open(media_path .. image.full_path, "w")
    file:write(image.content)
    file:close()
end

local function delete_image(image)
    os.remove(media_path .. image.full_path)
end

return {
    -- Configuration
    set_allowed_formats = set_allowed_formats,
    set_base_folder = set_base_folder,

    -- Image control logic
    get_image = get_image,
    save_image = save_image,
    delete_image = delete_image
}