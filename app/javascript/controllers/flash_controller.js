import { Controller } from "@hotwired/stimulus"

export default class extends Controller{
	static targets = ["message"]

	connect(){
		this.timeout = setTimeout(() =>{
			this.dismiss()
		}, 5000)
	}

	disconnect(){
		this.element.remove()
	}
}
