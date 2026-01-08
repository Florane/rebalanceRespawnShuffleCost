# Rebalance Spree Continue Cost
Rebalances continue costs and shuffling costs by swapping them.

This is mainly an attempt at more professional-looking mod.

---

**CONTINUE**  
After every fail, the cost is slowly raised, starting from 6 coins.  
Has 2 modes of growth, Exponential(6→12→24→48, copes vanilla), and Linear(6→12→18→24).  
Implementation might cause compatability issues due to override of `continue_crime_spree` function. This is necessary for the heist pool to not shuffle after continues.  
Unlike vanilla shuffle, cost is *not reset* between heists, only on finishing spree.

![](https://storage.modworkshop.net/mods/images/ywht0ov8C26k3QsaIDWRO0oBY035Y6q9TKIOOPJA.webp)

---

**SHUFFLE**  
The cost of shuffle is static, and raised with the current level.  
This fully copies the behavior of vanilla continue by default.
However, normally used tweakdata values are not used and not changed.

![](https://storage.modworkshop.net/mods/images/Za36eOL40EHs6Vd7aYELG1QYVTD36viXgkAmddsm.webp)

---

**CUSTOMIZATION**  
Settings menu is made via [Auto Menu Builder](https://modworkshop.net/mod/29982) by [Hoppip](https://modworkshop.net/user/hoppip)
Modification allowing use of dividers has been made to the library.

![](https://storage.modworkshop.net/mods/images/YoYrevFUHo9K10xG5ZbXNfvT6RwVbeh2iBIs1AaC.webp)
