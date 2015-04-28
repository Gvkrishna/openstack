OpenStack Cookbook
==================
If you are looking for reliable cookbook able to install OpenStack then you
won't find it here ;) This one is currently in very early stage of development
and it's not ready for any searious usage.

Requirements
------------

#### cookbooks
- `hostsname` - openstack needs hostsname to configure /etc/hosts file on
  target machine

Attributes
----------
TODO: List your cookbook attributes here.

e.g.
#### openstack::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['openstack']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----
#### openstack::default
TODO: Write usage instructions for each cookbook.

e.g.
Just include `openstack` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[openstack]"
  ]
}
```

Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Karol Szuster
