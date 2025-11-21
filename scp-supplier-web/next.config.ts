import { createRequire } from 'node:module'
const require = createRequire(import.meta.url)

const nextConfig = {
  webpack: (config, { dev, isServer }) => {
    config.module.rules.push({
      test: /\.css$/,
      use: [
        !isServer && {
          loader: require.resolve('next/dist/build/webpack/loaders/next-style-loader'),
          options: {
            insert: 'head',
            esModule: true
          }
        },
        {
          loader: require.resolve('css-loader'),
          options: {
            importLoaders: 1,
            modules: false
          }
        },
        {
          loader: require.resolve('postcss-loader'),
          options: {
            postcssOptions: {
              config: './postcss.config.mjs'
            }
          }
        }
      ].filter(Boolean)
    })

    config.module.rules.push({
      test: /\.styl$/,
      oneOf: [
        {
          test: /\.module\.styl$/,
          use: [
            !isServer && {
              loader: require.resolve('next/dist/build/webpack/loaders/next-style-loader'),
              options: {
                insert: 'head',
                esModule: true
              }
            },
            {
              loader: require.resolve('css-loader'),
              options: {
                modules: {
                  exportLocalsConvention: 'camelCase',
                  localIdentName: dev ? '[name]__[local]__[hash:base64:5]' : '[hash:base64:8]'
                },
                importLoaders: 1
              }
            },
            {
              loader: require.resolve('stylus-loader')
            }
          ].filter(Boolean)
        },
        {
          use: [
            !isServer && {
              loader: require.resolve('next/dist/build/webpack/loaders/next-style-loader'),
              options: {
                insert: 'head',
                esModule: true
              }
            },
            require.resolve('css-loader'),
            {
              loader: require.resolve('stylus-loader')
            }
          ].filter(Boolean)
        }
      ]
    })

    return config
  }
}

export default nextConfig
