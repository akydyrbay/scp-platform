/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['localhost', 'api.scp-platform.com', 'staging-api.scp-platform.com', 'dev-api.scp-platform.com', 'images.unsplash.com'],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
      {
        protocol: 'http',
        hostname: 'localhost',
      },
    ],
  },
  env: {
    NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080/api/v1',
  },
  webpack: (config, { dev, isServer }) => {
    // CSS loader configuration
    config.module.rules.push({
      test: /\.css$/,
      use: [
        !isServer && {
          loader: require.resolve('next/dist/build/webpack/loaders/next-style-loader'),
          options: {
            insert: 'head',
            esModule: true,
          },
        },
        {
          loader: require.resolve('css-loader'),
          options: {
            importLoaders: 1,
            modules: false,
          },
        },
        {
          loader: require.resolve('postcss-loader'),
          options: {
            postcssOptions: {
              config: './postcss.config.js',
            },
          },
        },
      ].filter(Boolean),
    })

    // Stylus loader configuration
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
                esModule: true,
              },
            },
            {
              loader: require.resolve('css-loader'),
              options: {
                modules: {
                  exportLocalsConvention: 'camelCase',
                  localIdentName: dev ? '[name]__[local]__[hash:base64:5]' : '[hash:base64:8]',
                },
                importLoaders: 1,
              },
            },
            {
              loader: require.resolve('stylus-loader'),
            },
          ].filter(Boolean),
        },
        {
          use: [
            !isServer && {
              loader: require.resolve('next/dist/build/webpack/loaders/next-style-loader'),
              options: {
                insert: 'head',
                esModule: true,
              },
            },
            require.resolve('css-loader'),
            {
              loader: require.resolve('stylus-loader'),
            },
          ].filter(Boolean),
        },
      ],
    })

    return config
  },
}

module.exports = nextConfig

