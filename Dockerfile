# Use a pre-built, stable Flutter image
FROM cirrusci/flutter:3.19.0

# Create a non-root user to run the build
RUN useradd -m -u 1001 flutteruser

# Take ownership of the SDK and a home directory
RUN chown -R flutteruser:flutteruser /sdks/flutter
RUN chown -R flutteruser:flutteruser /home/flutteruser

# Set the working directory
WORKDIR /app

# Copy project files and set ownership
COPY --chown=flutteruser:flutteruser . .

# Switch to the non-root user
USER flutteruser

# Mark the SDK directory as safe for git
RUN git config --global --add safe.directory /sdks/flutter

# Get dependencies
RUN flutter pub get

# Build the APK
RUN flutter build apk --release --split-per-abi --no-tree-shake-icons

# The CMD from the original file to copy the output
CMD ["sh", "-c", "cp build/app/outputs/flutter-apk/*.apk /output/ 2>/dev/null && ls -la /output/ || echo 'No APK found - checking build directory...' && find build/ -name '*.apk' -type f"]
