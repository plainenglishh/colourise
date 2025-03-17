--!nolint LocalShadow

--[[local base64 = {}; do -- https://gist.github.com/metatablecat/1f6cd6f4495f95700eb1a686de4ebe5e
    local SEQ = {
        [0] = "A", "B", "C", "D", "E", "F", "G", "H",
        "I", "J", "K", "L", "M", "N", "O", "P",
        "Q", "R", "S", "T", "U", "V", "W", "X",
        "Y", "Z", "a", "b", "c", "d", "e", "f",
        "g", "h", "i", "j", "k", "l", "m", "n",
        "o", "p", "q", "r", "s", "t", "u", "v",
        "w", "x", "y", "z", "0", "1", "2", "3",
        "4", "5", "6", "7", "8", "9", "+", "/",
    }
    
    local STRING_FAST = {}
    local INDEX = {[61] = 0, [65] = 0}
    
    for key, val in ipairs(SEQ) do
        -- memoization
        INDEX[string.byte(val)] = key
    end
    
    -- string.char has a MASSIVE overhead, its faster to precompute
    -- the values for performance
    for i = 0, 255 do
        local c = string.char(i)
        STRING_FAST[i] = c
    end
        
    function base64.encode(str)
        local len = string.len(str)
        local output = table.create(math.ceil(len/4)*4)
        local index = 1
    
        for i = 1, len, 3 do
            local b0, b1, b2 = string.byte(str, i, i + 2)
            local b = bit32.lshift(b0, 16) + bit32.lshift(b1 or 0, 8) + (b2 or 0)
    
            output[index] = SEQ[bit32.extract(b, 18, 6)]
            output[index + 1] = SEQ[bit32.extract(b, 12, 6)]
            output[index + 2] = b1 and SEQ[bit32.extract(b, 6, 6)] or "="
            output[index + 3] = b2 and SEQ[bit32.band(b, 63)] or "="
    
            index += 4
        end
    
        return table.concat(output)
    end
    
    function base64.decode(hash)
        -- given a 24 bit word (4 6-bit letters), decode 3 bytes from it
        local len = string.len(hash)
        local output = table.create(len * 0.75)
        
        local index = 1
        for i = 1, len, 4 do
            local c0, c1, c2, c3 = string.byte(hash, i, i + 3)
    
            local b = 
                bit32.lshift(INDEX[c0], 18)
                + bit32.lshift(INDEX[c1], 12)
                + bit32.lshift(INDEX[c2], 6)
                + (INDEX[c3])
            
    
            output[index] = STRING_FAST[bit32.extract(b, 16, 8)]
            output[index + 1] = c2 ~= "=" and STRING_FAST[bit32.extract(b, 8, 8)] or "="
            output[index + 2] = c3 ~= "=" and STRING_FAST[bit32.band(b, 0xFF)] or "="
            index += 3
        end
    
        return table.concat(output)
    end
end]]

local ESC = "\u{001b}";
local CSI = `{ESC}[`;
local OSC = `{ESC}]`;
local ST = `{ESC}\\`;
local RST = CSI .. "0m";

local colour_enabled = true;

export type style_selector = {
    reset: colouriser,
    bold: colouriser,
    dim: colouriser,
    italic: colouriser,
    underline: colouriser,
    slow_blink: colouriser,
    fast_blink: colouriser,
    invert: colouriser,
    hide: colouriser,
    strike: colouriser,
    double_underline: colouriser,
    black: colouriser,
    red: colouriser,
    green: colouriser,
    yellow: colouriser,
    blue: colouriser,
    magenta: colouriser,
    cyan: colouriser,
    white: colouriser,
    bright_black: colouriser,
    bright_red: colouriser,
    bright_green: colouriser,
    bright_yellow: colouriser,
    bright_blue: colouriser,
    bright_magenta: colouriser,
    bright_cyan: colouriser,
    bright_white: colouriser,
    bg_black: colouriser,
    bg_red: colouriser,
    bg_green: colouriser,
    bg_yellow: colouriser,
    bg_blue: colouriser,
    bg_magenta: colouriser,
    bg_cyan: colouriser,
    bg_white: colouriser,
    bg_bright_black: colouriser,
    bg_bright_red: colouriser,
    bg_bright_green: colouriser,
    bg_bright_yellow: colouriser,
    bg_bright_blue: colouriser,
    bg_bright_magenta: colouriser,
    bg_bright_cyan: colouriser,
    bg_bright_white: colouriser,
    rgb: & ((r: number, g: number, b: number) -> colouriser)
         & ((hex: string) -> colouriser),

    bg_rgb: & ((r: number, g: number, b: number) -> colouriser)
            & ((hex: string) -> colouriser),
};

export type colouriser = style_selector & (...string) -> string;

export type colourise = style_selector & {
    set_colour_enabled: (enabled: boolean) -> (),
    link: (text: string, url: string) -> string,
};

local function parse_rgb_input(...): {number}
    local args = table.pack(...);
    if args.n == 1 then -- Hex
        local colour = tostring(args[1]);
        
        if string.sub(colour, 1, 1) == "#" then
            local rgb = {};
            
            string.sub(colour, 2):gsub("%x%x", function(byte)
                table.insert(rgb, tonumber(byte, 16) or error("invalid hex byte"));
            end);

            return rgb;
        else
            error("expected HEX string to begin with '#'");
        end
    elseif args.n == 3 then
        return {...};
    else
        error("unexpected arguments to 'rgb', expected a HEX string or three RGB values");
    end
end

local styles = {};

styles.reset            = "0";
styles.bold             = "1";
styles.dim              = "2";
styles.italic           = "3";
styles.underline        = "4";
styles.slow_blink       = "5";
styles.fast_blink       = "6";
styles.invert           = "7";
styles.hide             = "8";
styles.strike           = "9";
styles.double_underline = "21";
styles.black            = "30";
styles.red              = "31";
styles.green            = "32";
styles.yellow           = "33";
styles.blue             = "34";
styles.magenta          = "35";
styles.cyan             = "36";
styles.white            = "37";
styles.bright_black     = "90";
styles.bright_red       = "91";
styles.bright_green     = "92";
styles.bright_yellow    = "93";
styles.bright_blue      = "94";
styles.bright_magenta   = "95";
styles.bright_cyan      = "96";
styles.bright_white     = "97";
styles.bg_black         = "40";
styles.bg_red           = "41";
styles.bg_green         = "42";
styles.bg_yellow        = "43";
styles.bg_blue          = "44";
styles.bg_magenta       = "45";
styles.bg_cyan          = "46";
styles.bg_white         = "47";
styles.bg_bright_black  = "100";
styles.bg_bright_red    = "101";
styles.bg_bright_green  = "102";
styles.bg_bright_yellow = "103";
styles.bg_bright_blue   = "104";
styles.bg_bright_magenta = "105";
styles.bg_bright_cyan   = "106";
styles.bg_bright_white  = "107";

styles.rgb = function(_, ...)
    local ok, rgb = pcall(parse_rgb_input, ...);
    if not ok then
        error(rgb, 3);
    end

    return `38;2;{rgb[1]};{rgb[2]};{rgb[3]}`;
end

styles.bg_rgb = function(_, ...)
    local ok, rgb = pcall(parse_rgb_input, ...);
    if not ok then
        error(rgb, 3);
    end

    return `48;2;{rgb[1]};{rgb[2]};{rgb[3]}`;
end

local root_api = {};

function root_api.set_colour_enabled(enabled: boolean)
    colour_enabled = enabled;
end

function root_api.link(text: string, url: string): string
    return `{OSC}8;;{url}{ST}{text}{OSC}8;;{ST}`;
end

--[[function root_api.image(data: string|buffer, width: number?, height: number?): string
    local data = if type(data) == "string" then data else buffer.tostring(data);

    return `{OSC}1337;File=inline=1{if width then `;width={width}` else ""}{if height then `;height={height}` else ""}:{base64.encode(data)}{ST}`;
end]]

local colouriser = {};

function colouriser:__index(style_name: string): any
    if #self._styles == 0 and root_api[style_name] then
        return root_api[style_name];
    end

    local style = styles[style_name];
    if not style then
        return;
    end

    local new_styles = table.clone(self._styles);
    table.insert(new_styles, style_name);

    if type(style) == "string" then
        return setmetatable({ 
            _sgr_inner = self._sgr_inner .. ";" .. style,
            _styles = new_styles,
            _style_function = nil,
        }, colouriser);
    elseif type(style) == "function" then
        return setmetatable({ 
            _sgr_inner = self._sgr_inner,
            _styles = new_styles,
            _style_function = style,
        }, colouriser);
    end

    error("expected style to be a string or a function", 2);
end

function colouriser:__call(...): any
    if self._style_function then
        local seq: string = self._style_function(self, ...);
        local new_seq = self._sgr_inner;

        if seq then
            new_seq ..= ";" .. seq;
        end

        return setmetatable({
            _styles = self._styles,
            _sgr_inner = new_seq,
            _style_function = nil,
        }, colouriser);
    else
        local inner = table.concat({...});
        if not colour_enabled then
            return inner;
        else
            return tostring(self) .. inner .. RST;
        end
    end
end

function colouriser:__tostring(): string
    if self._style_function then 
        return "<incomplete colouriser> " 
    else 
        if not colour_enabled then
            return "";
        end

        return CSI .. self._sgr_inner .. "m";
    end
end

function colouriser:__newindex(): never
    error("read only", 2);
end

function colouriser:__concat(with: string): string
    if type(with) == "string" then
        return tostring(self) .. with;
    else
        return self .. tostring(with);
    end
end

return (setmetatable({ 
    _styles = {},
    _sgr_inner = "",
    _style_function = nil,
}, colouriser) :: any) :: colourise;