
credentials-: ;

credentials-%:
	make dev.$*.credentials

discovery-: ;

discovery-%:
	make dev.$*.discovery

ecommerce-: ;

ecommerce-%:
	make dev.$*.ecommerce

e2e-: ;

e2e-%:
	make dev.$*.e2e

registrar-: ;

registrar-%:
	make dev.$*.registrar

xqueue-: ;

xqueue-%:
	make dev.$*.xqueue

xqueue_consumer-: ;

xqueue_consumer-%:
	make dev.$*.xqueue_consumer

lms-: ;

lms-%:
	make dev.$*.lms

#studio-: ;

#studio-%:
	make dev.$*.studio

studio_watcher-: ;

studio_watcher-%:
	make dev.$*.studio_watcher

lms_watcher-: ;

lms_watcher-%:
	make dev.$*.lms_watcher

lms-watcher-: ;

lms-%:
	make dev.$*.lms

studio-watcher-: ;

studio-watcher-%:
	make dev.$*.studio


marketing-% : dev.%.marketing
