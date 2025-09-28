package = 'chotto'
version = 'main-5'
source = {
   url = 'https://github.com/aiya000/chotto.lua'
}
description = {
   homepage = 'https://github.com/aiya000/chotto.lua',
   license = 'MIT'
}
build = {
   type = 'builtin',
   modules = {
      chotto = 'src/chotto.lua'
   }
}
