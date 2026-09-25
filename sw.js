const CACHE='scl-static-v80';
self.addEventListener('install',event=>{self.skipWaiting();});
self.addEventListener('activate',event=>{event.waitUntil(self.clients.claim());});
self.addEventListener('notificationclick',event=>{event.notification.close();event.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(clients=>{for(const c of clients){if('focus' in c)return c.focus();}return self.clients.openWindow('./');}));});
self.addEventListener('push',event=>{let data={title:'SCL Notification',body:'You have a new SCL notification.',url:'./'};try{if(event.data)data={...data,...event.data.json()};}catch(_){try{if(event.data)data.body=event.data.text();}catch(__){}}
event.waitUntil(self.registration.showNotification(data.title,{body:data.body,icon:'./favicon.ico',badge:'./favicon.ico',data:{url:data.url||'./'},tag:data.tag||'scl-notification'}));});
