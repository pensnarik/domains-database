/* pgmigrate-encoding: utf-8 */

insert into config.tag_meta (id, tag_id, name) values(1, 53, 'jQuery version');
insert into config.tag_meta (id, tag_id, name) values(2, 58, 'Magento version');

insert into config.tag_meta_expression (id, meta_id, expression)
values(1, 1, $$<script.{0,100}?src\\s{0,10}=\\s{0,10}['"][^'"]{1,200}jquery-([a-z0-9-.]{0,50})\\.js['"]$$);

insert into config.tag_meta_expression (id, meta_id, expression)
values(2, 1, $$<script.{0,100}?src\\s{0,10}=\\s{0,10}['"][^'"]{1,200}jquery\\/([a-z0-9-.]{0,50})\\/jquery\\.min\\.js['"]$$);

insert into config.tag_meta_expression (id, meta_id, expression)
values(3, 1, $$<script.{0,100}\s{1,10}src\s{0,10}=\s{0,10}['"][^'"]{1,200}jquery-([0-9a-z-.]{1,50})\.min\.js['"]$$);

insert into config.tag_meta_expression (id, meta_id, expression)
values (4, 2, $$<strong>(?:Report All Bugs|Сообщайте обо всех ошибках)<\/strong><\/a> \(ver\. ([0-9.a-z]{2,20})\)$$);