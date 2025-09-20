module.exports = {
  configureWebpack: {
    devtool: "source-map"
  },
  devServer: {
    proxy: {
      "/api": {
        target: "http://localhost:4000"
      }
    }
  },
  css: {
    loaderOptions: {
      sass: {
        prependData: `@import "@/palette.scss";`
      }
    }
  }
};
