local colors = {
  bg       = '#1C1B22',
  fg       = '#E6E1E5',
  primary  = '#D0BCFF',
  secondary= '#7FCFD4',
  tertiary = '#FFB2CD',
  warning  = '#FFE082',
  error    = '#F2B8B5',
  success  = '#A5D6A7',
  gray     = '#2A2931',
  darkgray = '#12121A',
}

return {
  normal = {
    a = { bg = colors.primary, fg = colors.darkgray, gui = 'bold' },
    b = { bg = colors.gray, fg = colors.fg },
    c = { bg = colors.bg, fg = colors.fg },
  },
  insert = {
    a = { bg = colors.secondary, fg = colors.darkgray, gui = 'bold' },
    b = { bg = colors.gray, fg = colors.fg },
    c = { bg = colors.bg, fg = colors.fg },
  },
  visual = {
    a = { bg = colors.tertiary, fg = colors.darkgray, gui = 'bold' },
    b = { bg = colors.gray, fg = colors.fg },
    c = { bg = colors.bg, fg = colors.fg },
  },
  replace = {
    a = { bg = colors.warning, fg = colors.darkgray, gui = 'bold' },
    b = { bg = colors.gray, fg = colors.fg },
    c = { bg = colors.bg, fg = colors.fg },
  },
  inactive = {
    a = { bg = colors.bg, fg = colors.fg, gui = 'bold' },
    b = { bg = colors.bg, fg = colors.fg },
    c = { bg = colors.bg, fg = colors.fg },
  }
}
