make bootstrap STACK=nextjs-api-client \
  APP=m2c2-ts \
  PM=npm \
  OPENAPI=https://api.m2c2kit.com/openapi.json


# Interactive prompt (we’ll add this next)
bootstrapper bootstrap

# Non-interactive
bootstrapper bootstrap --stack nextjs --app dashboard --pm pnpm
bootstrapper bootstrap --stack api-client-openapi --app mylib --pm uv --openapi ./openapi.json
