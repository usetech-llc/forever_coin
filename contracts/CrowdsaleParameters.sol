pragma solidity 0.4.18;

contract CrowdsaleParameters {
    ///////////////////////////////////////////////////////////////////////////
    // Configuration Independent Parameters
    ///////////////////////////////////////////////////////////////////////////

    struct AddressTokenAllocation {
        address addr;
        uint256 amount;
    }

    uint256 public maximumICOCap = 350e6;

    // ICO period timestamps:
    // 1525777200 = May 8, 2018. 11am GMT
    // 1529406000 = June 19, 2018. 11am GMT
    uint256 public generalSaleStartDate = 1525777200;
    uint256 public generalSaleEndDate = 1529406000;

    // Vesting
    // 1592564400 = June 19, 2020. 11am GMT
    uint32 internal vestingTeam = 1592564400;
    // 1529406000 = Bounty to ico end date - June 19, 2018. 11am GMT
    uint32 internal vestingBounty = 1529406000;

    ///////////////////////////////////////////////////////////////////////////
    // Production Config
    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // QA Config
    ///////////////////////////////////////////////////////////////////////////

    AddressTokenAllocation internal generalSaleWallet = AddressTokenAllocation(0x8d6d63c22D114C18C2a0dA6Db0A8972Ed9C40343, 350e6);
    AddressTokenAllocation internal communityReserve =  AddressTokenAllocation(0xa7a629529599023207B3B89A7Ee792aD20e6A8fb, 450e6);
    AddressTokenAllocation internal team =              AddressTokenAllocation(0xD00094c27603BAde402d572e845354E31655F65B, 170e6);
    AddressTokenAllocation internal advisors =          AddressTokenAllocation(0x1eA0A708A84b2b45E99a6f8F0aef7434B7677ab8, 48e5);
    AddressTokenAllocation internal bounty =            AddressTokenAllocation(0xBF39026615AE31c0534e61132f4a306828fcd27a, 176e5);
    AddressTokenAllocation internal administrative =    AddressTokenAllocation(0xc1e49322D28EA5B6cEfb43E5069C64f5cd4015BF, 76e5);

    address internal playersReserve = 0xEBcA5942db228bd327f75ea8969EaCeb13800470;
}
