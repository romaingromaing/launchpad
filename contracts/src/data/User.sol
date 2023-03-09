// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../module/WhiteList.sol";

contract User is WhiteList {
    struct UserStruct {
        address project;
        address invest;
        address user; // 用户地址
        uint investTotal; // 投入总额
        uint reward; // 总奖励
        /* 算法结果值 */
        uint hasReward; // 已奖励池
    }

    // 用户类型
    mapping(address => mapping(address => uint)) userProjectType;

    // 用户投资情况
    mapping(address => mapping(address => UserStruct))
        public userInvitests; /* 用户地址 => 项目地址 => 用户投资情况 */

    function initWhiteInvest(
        address project,
        address _invest,
        uint investTotal,
        bytes32[] memory _proof
    ) external {
        require(
            userProjectType[msg.sender][project] == 0 ||
                userProjectType[msg.sender][project] == 1,
            "nonwhitelist investors"
        ); // 0 default; 1 whitelist accounts
        require(_invest == invest[project], "token not matching");
        uint nowTime = block.timestamp;
        UserStruct memory userInfo = userInvitests[msg.sender][project];

        bool userIsWhite = isWhite(project, _proof);

        require(userIsWhite, "you are not members of whitelists");

        // 限制池子必须有足够项目方代币
        require(
            whiteReserve[project] - whiteHasInvest[project] >= investTotal,
            "not enough project token"
        );

        // 限制单个用户投资配额
        uint userInvestTotal = userInfo.investTotal + investTotal;
        require(
            userInvestTotal <= whiteMaxBuy[project],
            "invest buy range overflow"
        );

        // 限制仅可在项目运行周期内投资
        require(
            startTime[project] <= nowTime && endTime[project] >= nowTime,
            "invest time overflow"
        );

        /* 投入代币 */
        bool isInverstSuccess = IERC20(_invest).transferFrom(
            msg.sender,
            address(this),
            investTotal
        );

        /* 投入成功 */
        if (isInverstSuccess) {
            _initUserBaseConfig(project, _invest);
            userInvitests[msg.sender][project].investTotal = userInvestTotal; // 用户投资总额
            userInvitests[msg.sender][project].reward =
                (ratio[project] * userInvestTotal) /
                10 ** 18; // 用户的总收益
            investToOwner[project] += investTotal; // 项目方可收到的货款
            projectPoolTotal[project] -=
                (investTotal * ratio[project]) /
                10 ** 18; // 预支池子里的项目方代币
            whiteHasInvest[project] += investTotal; // 更新白名单预留池
        }

        userProjectType[msg.sender][project] = 1;
    }

    function initUserInvest(
        address project,
        address _invest,
        uint investTotal
    ) external {
        require(
            userProjectType[msg.sender][project] == 0 ||
                userProjectType[msg.sender][project] == 2,
            "nonordinary investors"
        ); // 0 default; 2 ordinary accounts
        require(_invest == invest[project], "token not matching");
        uint nowTime = block.timestamp;
        UserStruct memory userInfo = userInvitests[msg.sender][project];
        // 限制池子必须有足够项目方代币
        if (isWhiteProject[project]) {
            require(
                userResrve[project] - userHasInvest[project] >= investTotal,
                "not enough project token"
            );
        } else {
            require(
                projectPoolTotal[project] -
                    (investTotal * ratio[project]) /
                    10 ** 18 >=
                    0,
                "not enough project token"
            );
        }

        // 限制单个用户投资配额
        uint userInvestTotal = userInfo.investTotal + investTotal;
        require(
            userInvestTotal >= investBuyMin[project] &&
                userInvestTotal <= investBuyMax[project],
            "invest buy range overflow"
        );

        // 限制仅可在项目运行周期内投资
        require(
            startTime[project] <= nowTime && endTime[project] >= nowTime,
            "invest time overflow"
        );

        /* 投入代币 */
        bool isInverstSuccess = IERC20(_invest).transferFrom(
            msg.sender,
            address(this),
            investTotal
        );

        /* 投入成功 */
        if (isInverstSuccess) {
            _initUserBaseConfig(project, _invest);
            userInvitests[msg.sender][project].investTotal = userInvestTotal; // 用户投资总额
            userInvitests[msg.sender][project].reward =
                (ratio[project] * userInvestTotal) /
                10 ** 18; // 用户的总收益
            investToOwner[project] += investTotal; // 项目方可收到的货款
            projectPoolTotal[project] -=
                (investTotal * ratio[project]) /
                10 ** 18; // 预支池子里的项目方代币
            userHasInvest[project] += investTotal; // 更新普通人预留池
        }

        userProjectType[msg.sender][project] = 2;
    }

    function _initUserBaseConfig(address project, address invest) private {
        userInvitests[msg.sender][project].project = project;
        userInvitests[msg.sender][project].invest = invest;
        userInvitests[msg.sender][project].user = msg.sender;
    }
}
