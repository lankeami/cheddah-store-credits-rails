// Shopify Embedded App - Form Submission Handler
// This ensures forms work properly in the Shopify admin iframe

document.addEventListener('DOMContentLoaded', function() {
  // Handle all form submissions in embedded app
  const forms = document.querySelectorAll('form[data-turbo="false"]');

  forms.forEach(form => {
    form.addEventListener('submit', function(e) {
      // Allow the form to submit normally
      // The key is that we're already in the embedded context with session
      return true;
    });
  });
});
