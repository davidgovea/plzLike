### **Note**: plzLike is unstable/not ready for production use. I will be adding tests and working on this soon.

# jQuery plzLike

### A jQuery plugin for Facebook like-gates, backed by Firebase or custom endpoint.

See http://davidgovea.github.io/plzLike for more details docs/description

## Usage

1. **Include jQuery:**

	```html
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.0.0/jquery.min.js"></script>
	```

2. **Data store:**
  i. **Option 1**: Sign up for [Firebase](http://firebase.com) and include firebase script:

	```html
	<script type='text/javascript' src='https://cdn.firebase.com/v0/firebase.js'></script>
	```
  ii. **Option 2**: Use your own web endpoint for data storage
      See WEBHOOK section for more details

3. **Include plzLike:**

	```html
	<link href="dist/jquery.plzlike.min.css" rel="stylesheet"/>
	<script src="dist/jquery.plzlike.min.js"></script>
	```
4. **Call the plugin:**

	```javascript
	$("#element").plzLike({
		appId: <Facebook App ID>,
		page: <Facebook Page name>,
		firebaseUrl: <Firebase endpoint URL>
	});
	```

## License

[MIT License](http://davidgovea.mit-license.org/)
