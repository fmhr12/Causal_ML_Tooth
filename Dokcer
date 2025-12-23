FROM rocker/shiny:4.4.2

# Install system dependencies.
# 'build-essential' is added here because 'grf' needs to compile C++ code.
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install ONLY the packages this specific app needs.
# We removed riskRegression, fastshap, etc. to save build time.
RUN R -e "install.packages(c('shinythemes', 'grf'), repos='https://cran.rstudio.com/')"

# Copy all files (app.R and csf_deploy_data.rds) into the image.
COPY . /app
WORKDIR /app

# Expose port 10000 (Render's default).
EXPOSE 10000

# Run the Shiny app using the Render-friendly port logic.
CMD R -e "shiny::runApp('/app', host='0.0.0.0', port=as.numeric(Sys.getenv('PORT', 10000)))"
