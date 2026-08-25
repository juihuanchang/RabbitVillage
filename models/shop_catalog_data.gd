class_name ShopCatalogData
extends Resource

var products: Array[ShopProductData] = []

func get_product(product_id: String) -> ShopProductData:
	for product: ShopProductData in products:
		if product.product_id == product_id: return product
	return null
